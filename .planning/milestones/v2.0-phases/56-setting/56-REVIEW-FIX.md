---
phase: 56-setting
fixed_at: 2026-07-01T20:30:00Z
review_path: .planning/phases/56-setting/56-REVIEW.md
iteration: 2
findings_in_scope: 5
fixed: 3
skipped: 2
status: partial
---

# Phase 56: Code Review Fix Report (re-review, post-fix cycle)

**Fixed at:** 2026-07-01T20:30:00Z
**Source review:** .planning/phases/56-setting/56-REVIEW.md
**Iteration:** 2

**Summary:**
- Findings in scope: 5 (fix_scope=all — includes Info items)
- Fixed: 3
- Skipped: 2

**Note:** This is the second review-fix cycle. Cycle 1 (CR-01, WR-01 spinner-flash,
WR-02 hardcoded version) is verified fixed in the re-review and its report is preserved
in git history (commit `054afa8a`). This report covers the fresh findings surfaced by
the re-review only.

**Verification:** `flutter analyze` on each changed Dart file → "No issues found!".
`flutter test test/architecture/legal_asset_parity_test.dart` → 3/3 passed (includes
the two new strengthened assertions).

## Fixed Issues

### WR-01: Japanese legal drafts contain Chinese-only vocabulary (上線 / 復核)

**Files modified:** `assets/legal/privacy_ja.md`, `assets/legal/terms_ja.md`, `assets/legal/tokusho_ja.md`
**Commit:** d666d794
**Applied fix:** Mechanically replaced the Chinese vocabulary that leaked into the
default-locale Japanese legal text: 上線 → 公開 (so 上線前 → 公開前) and 復核 → 確認.
Only the three `*_ja.md` files were touched; the `*_zh.md` files were left untouched
(their 上线 is correct Chinese — verified still present: 4/4/3 occurrences). These are
plain-text markdown assets, so no `flutter gen-l10n` and no CJK-scan implications.
Verified zero remaining 上線/復核 in the ja files after the edit.

### IN-01: `legal_asset_parity_test` asserts existence only, not parity

**Files modified:** `test/architecture/legal_asset_parity_test.dart`
**Commit:** 13b3dda1
**Applied fix:** Added two assertions beyond the existing existence check:
(1) each of the 9 assets is non-empty and its first non-blank line is a top-level
`# ` heading; (2) the count of `## ` section headers matches across the three locales
of each doc (cross-locale structural parity, with a `> 0` floor). Confirmed the
existing 9 drafts already satisfy the new assertions — the `##` counts match per doc
(privacy 8, terms 10, tokusho 8) so no relaxation or draft edits were needed. All 3
tests pass; file is analyzer-clean.

### IN-03: Sponsor launch failure swallowed with no diagnostic logging

**Files modified:** `lib/features/settings/presentation/widgets/legal_sponsor_section.dart`
**Commit:** 1ef10af6
**Applied fix:** Changed `catch (_) { ok = false; }` to
`catch (e) { ok = false; debugPrint('sponsor launch failed: $e'); }`, preserving the
neutral SnackBar UX (T-56-06) while leaving a diagnostic trail per the coding-style
"never silently swallow errors" rule. `debugPrint` is already available via the
existing `package:flutter/material.dart` import — no new import needed. File is
analyzer-clean.

## Skipped Issues

### IN-02: Placeholder `example.com` / `support@example.com` ship with no enforced launch gate

**File:** `lib/core/config/legal_urls.dart:18-23`, `assets/legal/*_*.md` (contact lines)
**Reason:** deferred (launch-checklist item). The `example.com` /
`support@example.com` placeholders are INTENTIONALLY present pre-launch and are
correctly marked `公開前に実際の連絡先に差し替え` / "to be replaced before launch".
Adding a test that runs in the normal `flutter test` suite and fails while
placeholders exist would break CI immediately (the placeholders are supposed to be
present right now). Chose to SKIP rather than add an inert release-mode assert, to
avoid introducing dead/misleading test code. Recorded as a deferred launch-checklist
enforcement item — a CI grep or release gate to be wired at the actual launch phase,
not in phase 56.
**Original issue:** `privacyPolicyHosted`, `termsOfUseHosted`, `donation` are all
`https://example.com/...` placeholders and legal contact lines use
`support@example.com`; nothing mechanically blocks a store submission with live
placeholders.

### IN-04: Non-localized `'Error: $error'` in settings error branch

**File:** `lib/features/settings/presentation/screens/settings_screen.dart:165`
**Reason:** out of phase-56 scope. The reviewer confirmed this line predates phase 56
(introduced by MOD-007, commit `05e2cc7f`, 2026-02-10); the only phase-56 change to
this file is the `LegalSponsorSection` + `Divider` insertion at lines 158-159. Fix
belongs to a separate settings/i18n cleanup pass, not this phase.
**Original issue:** The `settingsAsync.when(error: ...)` branch renders a hardcoded
English `'Error: $error'`, violating "all UI text via `S.of(context)`" and
interpolating a raw error object into the UI.

---

_Fixed: 2026-07-01T20:30:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 2_
