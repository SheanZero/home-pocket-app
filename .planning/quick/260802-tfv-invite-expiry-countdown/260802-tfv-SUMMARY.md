---
status: complete
date: 2026-08-02
commit: 3e04b70f
---

# Real-time family invite expiry countdown — Summary

- Added a shared family invite countdown that refreshes every second and formats remaining validity as `MM:SS`.
- At expiry, the clock changes to an alert icon and the localized short status changes to semantic red (`已失效` / `期限切れ` / `Expired`).
- Reused the component in Create Family, the inline Family Management invite card, and the owner invite sheet.
- Regenerated Chinese, Japanese, and English localizations.

## Verification

- TDD red: the shared countdown component did not exist.
- Deterministic widget test covers `01:01 → 01:00 → 已失效` and asserts the expired text uses `palette.error`.
- Focused countdown, Create Family, Family Management, and ARB parity suites: 22 passed, 0 failed.
- `flutter analyze`: 0 issues.
- `git diff --check`: passed.

Implemented in batch commit `3e04b70f`.
