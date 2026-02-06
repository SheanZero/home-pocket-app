# Drift Code Generation Blocker Investigation Report

**Date Started:** 2026-02-04
**Status:** In Progress
**Priority:** CRITICAL BLOCKER

---

## Problem Summary

Drift's code generation is producing DAO `.g.dart` files but **failing to generate `AppDatabase.g.dart`**, which is essential for database functionality. This blocks all progress on MOD-001 (Basic Accounting).

**Symptoms:**
- DAO files generate successfully: `transaction_dao.g.dart`, `book_dao.g.dart`, `tag_dao.g.dart`
- **Database file NOT generated:** `lib/features/accounting/data/database/app_database.g.dart`
- Build runner completes without errors but skips the critical database file

**Impact:**
- Cannot instantiate AppDatabase
- Cannot perform any database operations
- Completely blocks MOD-001 implementation

---

## Investigation Plan

### Task 1: Create Minimal Reproduction Case ✅ COMPLETED
**Objective:** Isolate whether issue is Drift itself or our project configuration

**Test Setup:**
- Location: `/tmp/test_drift_minimal`
- Configuration: Single table (UsersTable), single DAO (UserDao), minimal AppDatabase
- Drift version: 2.31.0 (latest)
- drift_dev version: 2.31.0 (latest)

**Result:** **PASS** ✅

**Files Generated:**
- ✅ `lib/daos/user_dao.g.dart` - **YES** (485 bytes)
- ✅ `lib/database.g.dart` - **YES** (12,501 bytes) ← **CRITICAL FILE GENERATED**

**Build Runner Output:**
```
  1s compiling builders/jit
  2s compiling builders/jit
  2s compiling builders/jit
  0s drift_dev on 16 inputs; lib/daos/user_dao.dart
  3s drift_dev on 16 inputs: 1 output; spent 2s sdk; lib/database.dart
  6s drift_dev on 16 inputs: 3 output; spent 3s analyzing, 2s sdk; lib/tables/users_table.dart
  6s drift_dev on 16 inputs: 4 skipped, 10 output, 2 no-op; spent 3s analyzing, 2s sdk
  0s source_gen:combining_builder on 8 inputs; lib/daos/user_dao.dart
  0s source_gen:combining_builder on 8 inputs: 4 skipped, 2 output, 2 no-op
  Built with build_runner/jit in 9s; wrote 12 outputs.
```

**Conclusion:**
🎯 **Drift itself works correctly. The issue is in the Home Pocket project configuration.**

**Next Steps:**
✅ Proceed to Task 2 - Test File Location Hypothesis

---

## Minimal Reproduction Test Results (Task 1)

**Date:** 2026-02-04
**Test Location:** /tmp/test_drift_minimal

**Result:** PASS

**Files Generated:**
- lib/daos/user_dao.g.dart: YES
- lib/database.g.dart: YES ← **This is the key file that fails in our main project**

**Conclusion:**
Drift itself works correctly. Issue is in Home Pocket project configuration.

**Next Steps:**
Proceed to Task 2 - test file location hypothesis

**Build Runner Output:**
```
  1s compiling builders/jit
  2s compiling builders/jit
  2s compiling builders/jit
  0s drift_dev on 16 inputs; lib/daos/user_dao.dart
  3s drift_dev on 16 inputs: 1 output; spent 2s sdk; lib/database.dart
  6s drift_dev on 16 inputs: 3 output; spent 3s analyzing, 2s sdk; lib/tables/users_table.dart
  6s drift_dev on 16 inputs: 4 skipped, 10 output, 2 no-op; spent 3s analyzing, 2s sdk
  0s source_gen:combining_builder on 8 inputs; lib/daos/user_dao.dart
  0s source_gen:combining_builder on 8 inputs: 4 skipped, 2 output, 2 no-op
  Built with build_runner/jit in 9s; wrote 12 outputs.
```

---

## Hypotheses to Test

### Hypothesis 1: File Location Depth (Task 2)
**Theory:** Database file is too deeply nested (`lib/features/accounting/data/database/`)

**Evidence:**
- Minimal test uses `lib/database.dart` → WORKS
- Main project uses `lib/features/accounting/data/database/app_database.dart` → FAILS

**Test Plan:** Move database file to `lib/` and re-run code generation

---

### Hypothesis 2: File Naming Convention (Task 3)
**Theory:** File name `app_database.dart` conflicts with something

**Evidence:**
- Minimal test uses `database.dart` → WORKS
- Main project uses `app_database.dart` → FAILS

**Test Plan:** Rename to `database.dart` and re-run code generation

---

### Hypothesis 3: Drift Version Issue (Task 4)
**Theory:** Drift 2.31.0 has a regression (less likely now)

**Evidence:**
- Minimal test with 2.31.0 → WORKS
- This hypothesis is now less likely but worth testing

**Test Plan:** Pin to Drift 2.14.0 (same as initial plan)

---

## Testing Queue

- [x] Task 1: Create Minimal Reproduction Case - **COMPLETED - PASS**
- [ ] Task 2: Test File Location Hypothesis - **NEXT**
- [ ] Task 3: Test File Naming Hypothesis
- [ ] Task 4: Test Drift Version Pinning (if 2-3 fail)
- [ ] Task 5: Seek Community Support (if all else fails)
- [ ] Task 6: Evaluate Alternative Database Solutions (last resort)

---

## Key Findings

### Finding 1: Drift Code Generation Works in Isolation
**Date:** 2026-02-04
**Test:** Minimal reproduction in `/tmp/test_drift_minimal`
**Result:** ✅ SUCCESS - `database.g.dart` generated correctly (12,501 bytes)
**Implication:** The problem is NOT with Drift itself, but with our project configuration

**Critical Differences Between Minimal Test and Main Project:**

| Aspect | Minimal Test (WORKS) | Main Project (FAILS) |
|--------|---------------------|----------------------|
| Database file path | `lib/database.dart` | `lib/features/accounting/data/database/app_database.dart` |
| File name | `database.dart` | `app_database.dart` |
| Directory depth | 1 level | 4 levels deep |
| Project complexity | Minimal (1 table, 1 DAO) | Full app (multiple features) |

**Most Likely Culprit:** File location depth (4 levels vs 1 level)

---

## Timeline

- **2026-02-04 15:10** - Task 1 completed: Minimal reproduction PASSED
- **2026-02-04 15:15** - Next: Task 2 (file location hypothesis)

---

## References

- **Drift Documentation:** https://drift.simonbinder.eu/
- **Minimal Test Project:** `/tmp/test_drift_minimal`
- **Main Project Database File:** `lib/features/accounting/data/database/app_database.dart`
- **Investigation Plan:** (embedded in this document)

---

**Last Updated:** 2026-02-04 15:15
**Next Action:** Execute Task 2 - Move database file to `lib/` and test
