# Drift Database Code Generation Blocker - Resolution Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Resolve Drift's AppDatabase.g.dart generation failure to unblock Phase 2 Data Layer implementation

**Architecture:** Systematic investigation approach starting with minimal reproduction, then testing file location, naming, and version hypotheses. Falls back to alternative database solutions if Drift proves unworkable.

**Tech Stack:**
- Flutter 3.x + Dart 3.2+
- Drift 2.14.0 / 2.28.2
- SQLCipher (encryption)
- build_runner 2.4.7+

---

## Investigation Strategy

This plan follows a **systematic elimination approach**:
1. Isolate the problem with minimal reproduction
2. Test environmental factors (file location, naming)
3. Test version compatibility
4. Seek community help
5. Evaluate alternatives only if all else fails

Each task includes:
- Exact commands to run
- Expected vs actual output
- Clear pass/fail criteria
- Rollback steps if needed

---

## Task 1: Create Minimal Reproduction Case

**Objective:** Determine if the issue is Drift itself or our project configuration

**Files:**
- Create: `test_drift_minimal/` (temporary directory outside project)

**Estimated Time:** 30 minutes

---

### Step 1: Create minimal Flutter project

**Command:**
```bash
cd /tmp
flutter create test_drift_minimal --empty
cd test_drift_minimal
```

**Expected Output:** New Flutter project created

---

### Step 2: Add minimal Drift dependencies

**Modify:** `pubspec.yaml`

Add dependencies:
```yaml
dependencies:
  flutter:
    sdk: flutter
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.18

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.14.0
  build_runner: ^2.4.7
```

**Command:**
```bash
flutter pub get
```

**Expected Output:** Dependencies resolved

---

### Step 3: Create single table

**Create:** `lib/tables/users_table.dart`

```dart
import 'package:drift/drift.dart';

class UsersTable extends Table {
  @override
  String get tableName => 'users';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text()();
}
```

---

### Step 4: Create single DAO

**Create:** `lib/daos/user_dao.dart`

```dart
import 'package:drift/drift.dart';
import 'package:test_drift_minimal/database.dart';
import 'package:test_drift_minimal/tables/users_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [UsersTable])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDao {
  UserDao(AppDatabase db) : super(db);

  Future<List<UsersTableData>> getAllUsers() => select(usersTable).get();
}
```

---

### Step 5: Create minimal AppDatabase

**Create:** `lib/database.dart`

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test_drift_minimal/daos/user_dao.dart';
import 'package:test_drift_minimal/tables/users_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [UsersTable],
  daos: [UserDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}
```

---

### Step 6: Run code generation

**Command:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Expected Output (PASS):**
```
[INFO] Generating build script completed, took 1.2s
[INFO] Reading cached asset graph completed, took 0.1s
[INFO] Checking for updates since last build completed, took 0.5s
[INFO] Running build completed, took 2.3s
[INFO] Caching finalized dependency graph completed, took 0.1s
[INFO] Succeeded after 2.5s with 3 outputs (3 actions)
```

Files generated:
- ✅ `lib/daos/user_dao.g.dart`
- ✅ `lib/database.g.dart` ← **THIS IS THE KEY FILE**

**Expected Output (FAIL):**
```
[INFO] Succeeded after 2.5s with 2 outputs (2 actions)
```

Files generated:
- ✅ `lib/daos/user_dao.g.dart`
- ❌ `lib/database.g.dart` ← **Missing**

---

### Step 7: Analyze result

**If PASS (database.g.dart generated):**
- ✅ Drift itself works correctly
- ❌ Issue is in our project configuration
- → Proceed to Task 2 (test file location)

**If FAIL (database.g.dart not generated):**
- ❌ Drift has a fundamental issue
- → Proceed to Task 3 (test versions)

---

### Step 8: Commit investigation result

**Command:**
```bash
# In main project
cd /Users/xinz/Development/home-pocket-app/.worktrees/mod-001-basic-accounting

# Document findings
echo "Minimal reproduction result: [PASS/FAIL]" >> docs/drift-blocker-problem-report.md
echo "Database file generated: [YES/NO]" >> docs/drift-blocker-problem-report.md
echo "Conclusion: [Drift works / Drift broken]" >> docs/drift-blocker-problem-report.md

git add docs/drift-blocker-problem-report.md
git commit -m "docs: document minimal Drift reproduction test result"
```

---

## Task 2: Test File Location Hypothesis

**Objective:** Determine if feature module structure prevents generation

**Prerequisite:** Task 1 showed Drift works in minimal case

**Files:**
- Modify: `lib/features/accounting/data/datasources/local/app_database.dart` → move to `lib/data/app_database.dart`

**Estimated Time:** 20 minutes

---

### Step 1: Create lib/data directory

**Command:**
```bash
mkdir -p lib/data/datasources/local/tables
mkdir -p lib/data/datasources/local/daos
```

---

### Step 2: Move database file to flat structure

**Command:**
```bash
# Move AppDatabase
mv lib/features/accounting/data/datasources/local/app_database.dart \
   lib/data/app_database.dart

# Move tables
cp lib/features/accounting/data/datasources/local/tables/*.dart \
   lib/data/datasources/local/tables/

# Move DAOs
cp lib/features/accounting/data/datasources/local/daos/*.dart \
   lib/data/datasources/local/daos/
```

---

### Step 3: Update imports in app_database.dart

**Modify:** `lib/data/app_database.dart`

Change imports from:
```dart
import 'package:home_pocket/features/accounting/data/datasources/local/daos/transaction_dao.dart';
```

To:
```dart
import 'package:home_pocket/data/datasources/local/daos/transaction_dao.dart';
```

---

### Step 4: Update build.yaml

**Modify:** `build.yaml`

Change:
```yaml
drift_dev:
  generate_for:
    - lib/data/datasources/local/**/*.dart
    - lib/features/**/data/datasources/local/**/*.dart
```

To:
```yaml
drift_dev:
  generate_for:
    - lib/data/**/*.dart
```

---

### Step 5: Clean and regenerate

**Command:**
```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

---

### Step 6: Check for database.g.dart

**Command:**
```bash
ls -la lib/data/app_database.g.dart
```

**Expected Output (PASS):**
```
-rw-r--r--  1 user  staff  5432 Feb  4 15:30 lib/data/app_database.g.dart
```

**Expected Output (FAIL):**
```
ls: lib/data/app_database.g.dart: No such file or directory
```

---

### Step 7: Analyze result and rollback if needed

**If PASS:**
- ✅ File location was the issue
- → Keep new structure
- → Update all feature imports
- → Proceed to testing

**If FAIL:**
- ❌ File location not the issue
- → Rollback changes:
```bash
git reset --hard HEAD
```
- → Proceed to Task 3 (test naming)

---

### Step 8: Commit if successful

**Command:**
```bash
git add lib/data/ build.yaml
git commit -m "fix: move AppDatabase to flat structure for Drift generation"
```

---

## Task 3: Test File Naming Hypothesis

**Objective:** Determine if file name affects generation

**Prerequisite:** Task 2 failed or was skipped

**Files:**
- Rename: `app_database.dart` → `database.dart`

**Estimated Time:** 15 minutes

---

### Step 1: Rename database file

**Command:**
```bash
# Current location (adjust based on Task 2 result)
mv lib/features/accounting/data/datasources/local/app_database.dart \
   lib/features/accounting/data/datasources/local/database.dart
```

---

### Step 2: Update imports in DAOs

**Modify:** All DAO files

Change:
```dart
import 'package:home_pocket/features/accounting/data/datasources/local/app_database.dart';
```

To:
```dart
import 'package:home_pocket/features/accounting/data/datasources/local/database.dart';
```

**Files to update:**
- `lib/features/accounting/data/datasources/local/daos/transaction_dao.dart`
- `lib/features/accounting/data/datasources/local/daos/category_dao.dart`
- `lib/features/accounting/data/datasources/local/daos/book_dao.dart`

---

### Step 3: Update part directive

**Modify:** `lib/features/accounting/data/datasources/local/database.dart`

Change:
```dart
part 'app_database.g.dart';
```

To:
```dart
part 'database.g.dart';
```

---

### Step 4: Clean and regenerate

**Command:**
```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

---

### Step 5: Check for database.g.dart

**Command:**
```bash
ls -la lib/features/accounting/data/datasources/local/database.g.dart
```

**Expected Output (PASS):** File exists

**Expected Output (FAIL):** File not found

---

### Step 6: Rollback if failed

**If FAIL:**
```bash
git reset --hard HEAD
```

---

### Step 7: Commit if successful

**Command:**
```bash
git add lib/features/accounting/data/datasources/local/
git commit -m "fix: rename app_database.dart to database.dart for Drift generation"
```

---

## Task 4: Test Drift Version Pinning

**Objective:** Determine if version mismatch causes issue

**Prerequisite:** Tasks 1-3 did not resolve the issue

**Files:**
- Modify: `pubspec.yaml`

**Estimated Time:** 20 minutes

---

### Step 1: Pin Drift to exact 2.14.0

**Modify:** `pubspec.yaml`

Change:
```yaml
dependencies:
  drift: ^2.14.0

dev_dependencies:
  drift_dev: ^2.14.0
```

To:
```yaml
dependencies:
  drift: 2.14.0  # Exact version

dev_dependencies:
  drift_dev: 2.14.0  # Exact version
```

---

### Step 2: Clean and reinstall

**Command:**
```bash
flutter pub get
dart run build_runner clean
rm -rf .dart_tool/build
```

---

### Step 3: Verify exact versions

**Command:**
```bash
flutter pub deps | grep drift
```

**Expected Output:**
```
drift 2.14.0
drift_dev 2.14.0
```

---

### Step 4: Regenerate with pinned version

**Command:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

### Step 5: Check result

**Command:**
```bash
find lib -name "*database.g.dart"
```

**Expected Output (PASS):** File path shown

**Expected Output (FAIL):** No files found

---

### Step 6: If failed, try upgrading build_runner

**Modify:** `pubspec.yaml`

Change:
```yaml
build_runner: ^2.4.7
```

To:
```yaml
build_runner: ^2.4.8  # Latest
```

**Command:**
```bash
flutter pub get
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

---

### Step 7: Commit successful version

**Command:**
```bash
git add pubspec.yaml pubspec.lock
git commit -m "fix: pin Drift to version [version] for stable code generation"
```

---

## Task 5: Seek Community Support

**Objective:** Get help from Drift maintainers and community

**Prerequisite:** Tasks 1-4 exhausted without resolution

**Files:**
- Create: `docs/drift-github-issue.md` (draft)

**Estimated Time:** 1 hour

---

### Step 1: Search Drift GitHub Issues

**Manual Research:**
1. Visit https://github.com/simolus3/drift/issues
2. Search for: "AppDatabase.g.dart not generating"
3. Search for: "@DriftDatabase not generating"
4. Search for: "code generation DAOs work database doesn't"

**Document findings:**
```bash
echo "## GitHub Issue Search Results" >> docs/drift-blocker-problem-report.md
echo "- Issue #XXX: [description]" >> docs/drift-blocker-problem-report.md
```

---

### Step 2: Check Drift Discord

**Manual Research:**
1. Visit Drift Discord server
2. Search #help channel for similar issues
3. Check pinned messages for known issues

---

### Step 3: Prepare minimal reproduction for issue

**Create:** `docs/drift-github-issue.md`

```markdown
# AppDatabase.g.dart not generating (DAOs generate successfully)

## Environment

- Flutter: 3.x
- Dart: 3.2.0
- drift: 2.14.0 / 2.28.2
- drift_dev: 2.14.0 / 2.28.2
- build_runner: 2.4.7
- OS: macOS / Linux / Windows

## Issue Description

build_runner successfully generates DAO `.g.dart` files but consistently fails to generate `AppDatabase.g.dart`.

## Minimal Reproduction

[Paste code from Task 1 minimal reproduction]

## Expected Behavior

`lib/database.g.dart` should be generated containing `_$AppDatabase` class.

## Actual Behavior

Only `lib/daos/user_dao.g.dart` is generated. Database file is never created.

build_runner output:
```
[INFO] Succeeded after 2.5s with 2 outputs
```

No errors or warnings are shown.

## What I've Tried

- ✅ Verified @DriftDatabase annotation syntax
- ✅ Tried different file locations (feature modules vs flat)
- ✅ Tried different file names (app_database.dart vs database.dart)
- ✅ Pinned to exact drift versions (2.14.0)
- ✅ Cleaned all caches (.dart_tool, flutter clean)
- ✅ Tested with minimal reproduction (see above)

## Question

Is there a known issue with @DriftDatabase code generation in recent versions? Are there any additional build.yaml settings required?

Thank you!
```

---

### Step 4: Post issue (if no existing solution found)

**Action:** Create GitHub issue or Discord post with content from Step 3

**Document:**
```bash
echo "GitHub Issue: https://github.com/simolus3/drift/issues/XXXX" >> docs/drift-blocker-problem-report.md
```

---

### Step 5: Commit documentation update

**Command:**
```bash
git add docs/
git commit -m "docs: document Drift community support request"
```

---

## Task 6: Evaluate Alternative Database Solutions

**Objective:** Assess alternatives if Drift remains unworkable

**Prerequisite:** Tasks 1-5 exhausted, issue unresolved after 48 hours

**Files:**
- Create: `docs/database-alternatives-evaluation.md`

**Estimated Time:** 2 hours

---

### Step 1: Document evaluation criteria

**Create:** `docs/database-alternatives-evaluation.md`

```markdown
# Database Solution Alternatives - Evaluation

## Evaluation Criteria

| Criterion | Weight | Notes |
|-----------|--------|-------|
| SQLCipher support | 🔴 CRITICAL | Must have encryption |
| Type safety | 🟡 HIGH | Prefer compile-time checking |
| Migration support | 🟡 HIGH | Need schema versioning |
| Code generation reliability | 🔴 CRITICAL | Must work consistently |
| Performance | 🟢 MEDIUM | Good enough for mobile |
| Community support | 🟢 MEDIUM | Active maintenance |
| Learning curve | 🟢 LOW | Can invest time if needed |

## Alternatives

### Option 1: Direct sqflite + SQLCipher

### Option 2: Floor ORM

### Option 3: Isar Database

### Option 4: Moor (Drift predecessor)

[Detailed analysis to be filled in]
```

---

### Step 2: Research sqflite + SQLCipher

**Manual Research:**
- Check sqflite_sqlcipher package
- Review type safety approach
- Assess migration strategy

**Document findings in evaluation doc**

---

### Step 3: Research Floor ORM

**Manual Research:**
- Check Floor package status
- Compare API to Drift
- Assess code generation reliability

**Document findings in evaluation doc**

---

### Step 4: Create recommendation

**Add to evaluation doc:**

```markdown
## Recommendation

Based on evaluation:

**Recommended:** [Solution name]

**Rationale:**
- [Pro 1]
- [Pro 2]
- [Pro 3]

**Migration Effort:** [X] hours

**Risks:**
- [Risk 1]
- [Risk 2]

## Implementation Plan

If approved:
1. [Step 1]
2. [Step 2]
...
```

---

### Step 5: Commit evaluation

**Command:**
```bash
git add docs/database-alternatives-evaluation.md
git commit -m "docs: evaluate alternative database solutions to Drift"
```

---

## Task 7: Implement Chosen Alternative (If Needed)

**Objective:** Migrate away from Drift if no resolution found

**Prerequisite:** Task 6 completed, decision made

**Estimated Time:** 1-2 days (depends on alternative)

**Note:** This task will require a separate detailed plan based on chosen alternative.

---

## Success Criteria

This investigation plan succeeds when **ANY** of these conditions is met:

1. ✅ **Drift Works:** `AppDatabase.g.dart` generates successfully
2. ✅ **Workaround Found:** Reliable manual pattern that doesn't break Drift's features
3. ✅ **Alternative Selected:** Documented, approved alternative with migration plan
4. ❌ **Escalation:** After 8 hours investigation, escalate to architecture review

---

## Rollback Plan

If investigation breaks existing functionality:

```bash
# Restore working state
git reset --hard [commit-before-investigation]

# Restore manual AppDatabase workaround
git cherry-pick [manual-database-commit]

# Verify Application Layer still works
flutter test test/features/accounting/application/
```

---

## References

- **Problem Report:** `docs/drift-blocker-problem-report.md`
- **Task Tracker:** `docs/plans/2026-02-04-mod-001-task-tracker.md`
- **Original Blocker Log:** `doc/worklog/20260204_1432_drift_database_generation_blocker.md`
- **Drift Documentation:** https://drift.simonbinder.eu/
- **Drift GitHub:** https://github.com/simolus3/drift

---

**Plan Created:** 2026-02-04
**Estimated Total Time:** 4-8 hours investigation, up to 2 days if migration needed
**Author:** Claude Sonnet 4.5
**Status:** Ready for execution
