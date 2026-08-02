---
status: complete
date: 2026-08-02
commit: 3e04b70f
---

# Warm family invite share copy — Summary

- Replaced the raw-code share payload on the Create Family invite step with the shared localized invitation template already used by Family Management.
- Applied the selected warm Chinese copy and equivalent Japanese and English versions, including the group name, invite code, and ten-minute validity guidance.
- Added an injectable share callback and a Chinese widget regression test that asserts the complete share payload.
- Regenerated Flutter localizations.

## Verification

- TDD red: CreateGroupScreen had no injectable share action and shared only the raw code.
- Focused create-family, group-management, and ARB parity suites: 21 passed, 0 failed.
- `flutter analyze`: 0 issues.
- `git diff --check`: passed.

Implemented in batch commit `3e04b70f`.
