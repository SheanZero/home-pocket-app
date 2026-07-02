# Phase 56 — Deferred / Out-of-Scope Items

## Discovered during 56-07 (tokusho full 表記型 gap-closure), 2026-07-02

### DEF-56-07-01 — Pre-existing full-suite failure (out of scope for 56-07)

- **Test:** `test/architecture/production_logging_privacy_test.dart` › "production logging privacy scanner production code does not contain unsafe logging"
- **Failure:** `lib/features/settings/presentation/widgets/legal_sponsor_section.dart:50: logging must be guarded by kDebugMode`
- **Root:** unguarded `debugPrint('sponsor launch failed: $e')` added by commit `1ef10af6` (2026-07-01, plan 56-06 "IN-03 log sponsor launch failure"), BEFORE 56-07 started.
- **Why out of scope:** 56-07's files_modified list is limited to the 3 tokusho assets, `legal_doc_screen_test.dart`, and `56-CONTEXT.md`. `legal_sponsor_section.dart` was NOT touched by any 56-07 commit (verified via `git diff --name-only`). Fixing it would require editing a file owned by plan 56-06.
- **Suggested fix (for the owning plan / a follow-up):** wrap the `debugPrint` at line 50 in `if (kDebugMode) { ... }` (already imported pattern elsewhere), or route through the project's guarded logger.
- **Status:** NOT fixed here (scope boundary). Full suite result at end of 56-07: 3492 passed / 1 failed (this item).
