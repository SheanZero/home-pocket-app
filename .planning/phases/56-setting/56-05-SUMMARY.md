---
phase: 56-setting
plan: 05
subsystem: settings
status: complete
tags: [settings, legal, donation, url_launcher, i18n, tone-c]
requires:
  - LegalUrls.donation (56-01)
  - url_launcher ^6.3.2 (56-01)
  - S getters legalSponsorSectionTitle/termsOfUse/tokushoNotice/tokushoNoticeSubtitle/sponsorRow/sponsorRowSubtitle/sponsorLaunchError (56-03)
  - LegalDocScreen + LegalDoc enum (56-04)
provides:
  - LegalSponsorSection (5-row 法的情報・応援 group widget)
  - AboutSection slimmed to version-only
affects:
  - 56-06 (inserts const LegalSponsorSection() into settings_screen.dart)
tech_stack:
  added:
    - "dev_dependency plugin_platform_interface ^2.1.8 (test mock surface)"
    - "dev_dependency url_launcher_platform_interface ^2.3.2 (test mock surface)"
  patterns:
    - "external-browser launch via launchUrl(externalApplication) without canLaunch gate (Android 11+ false-negative)"
    - "UrlLauncherPlatform.instance mock (Fake + MockPlatformInterfaceMixin) for launch assertions"
key_files:
  created:
    - lib/features/settings/presentation/widgets/legal_sponsor_section.dart
    - test/widget/features/settings/legal_sponsor_section_test.dart
  modified:
    - lib/features/settings/presentation/widgets/about_section.dart
    - pubspec.yaml
    - pubspec.lock
decisions:
  - "External-link affordance rendered as Icons.open_in_new colored context.palette.shared (ADR-019 steel-blue) — the sketch's 「↗ 外部」 CJK label is dropped to satisfy hardcoded_cjk_ui_scan (no S key exists for it); tone-C var(--shared) fidelity preserved via the icon color"
  - "Sponsor launch uses captured ScaffoldMessenger + context.mounted guard (analyzer-clean async-context); direct launchUrl, no canLaunch gate"
  - "AboutSection slimmed to version-only; privacy + OSS-license tiles now live solely in LegalSponsorSection (no duplicates, tone-C)"
metrics:
  duration: ~15 min
  completed: 2026-07-01
  tasks: 2
  files: 5
requirements_completed: [DONATE-01, DONATE-02, DONATE-03, LEGAL-03]
---

# Phase 56 Plan 05: Legal/Sponsor Section Widget Summary

Built `LegalSponsorSection` — the phase's visible surface — as a version-only-independent Column mirroring `about_section.dart`: 5 tone-C rows (privacy / 利用規約 / 特商法 / OSS ライセンス / 開発を応援する) where privacy/terms/tokusho push the offline `LegalDocScreen`, OSS reuses the framework `showLicensePage`, and the sponsor row launches the external browser at `LegalUrls.donation` via `url_launcher` (`LaunchMode.externalApplication`, no dialog/WebView/IAP). `AboutSection` was slimmed to version-only so the privacy/license entries live in exactly one place.

## What was built

**Task 1 — LegalSponsorSection (test-first):**
- 7 widget tests written RED first (section absent → compile failure), then GREEN.
- Tests mock `UrlLauncherPlatform.instance` with a `Fake + MockPlatformInterfaceMixin` capturing `lastUrl`/`lastOptions`; assert `lastUrl == LegalUrls.donation` and `lastOptions.mode == PreferredLaunchMode.externalApplication`.
- Coverage: 5-row render, nav-to-LegalDocScreen with matching `LegalDoc` (privacy/terms/tokusho), `showLicensePage` on OSS row, external launch params, no-AlertDialog (DONATE-03), neutral SnackBar on launch failure (T-56-06), and the `palette.shared`-colored affordance.
- Implementation: `StatelessWidget`; sponsor row's `_openSponsor` captures messenger/l10n before the await, launches directly (no `canLaunch` gate — Android 11+ false-negative), and shows one neutral `SnackBar(sponsorLaunchError)` only if `!ok && context.mounted`.

**Task 2 — AboutSection slim:**
- Removed the dead privacy-policy `ListTile` (the `// TODO: Navigate` stub) and the OSS-license `ListTile`; kept the `about` title + `version` tile.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added url_launcher test interfaces as dev_dependencies**
- **Found during:** Task 2 wave-gate `flutter analyze`.
- **Issue:** `legal_sponsor_section_test.dart` imports `plugin_platform_interface` and `url_launcher_platform_interface` (both transitive via `url_launcher`), triggering two `depend_on_referenced_packages` info issues — violating the project's 0-analyzer-issue guardrail (CLAUDE.md / audit.yml).
- **Fix:** Added both to `dev_dependencies` pinned to their already-resolved versions (`^2.1.8` / `^2.3.2`). `flutter pub get` resolved without touching the pinned win32 trio.
- **Files modified:** pubspec.yaml, pubspec.lock
- **Commit:** e467033a

### Design adaptation (not a bug)

The approved tone-C sketch renders the external affordance as `「↗ 外部」` text colored `var(--shared)`. "外部" is a CJK literal with no S getter, and `hardcoded_cjk_ui_scan` scans `lib/` for hardcoded CJK. Rendered the affordance as `Icon(Icons.open_in_new, color: context.palette.shared)` instead — preserves the `var(--shared)` steel-blue fidelity and the external-link semantics without a hardcoded CJK string. Documented as a decision above.

## Verification

- `flutter test test/widget/features/settings/legal_sponsor_section_test.dart` → 7/7 GREEN, exit 0.
- Acceptance greps: `showLicensePage(` present, `LaunchMode.externalApplication` present, `LegalUrls.donation` present, `palette.shared` present, `canLaunchUrl` absent, no `primary`/hardcoded-hex on affordance.
- `about_section.dart`: no `showLicensePage`/`privacyPolicy`; `S.of(context).version` intact.
- FULL `flutter test` → 3490/3490 passed, exit 0 (wave gate; not piped through tail).
- `flutter analyze` → No issues found (0).
- `hardcoded_cjk_ui_scan` architecture test → passes (CJK only in doc comments).

## Notes for downstream (56-06)

- Insert `const LegalSponsorSection()` into `settings_screen.dart` before/around `AboutSection` — that wiring is 56-06's job (not done here).
- `LegalUrls.donation` is still a `上线前填真实值` placeholder — real sponsor URL must be filled before store submission.
- On-device UAT still owed: confirm the external browser actually opens the sponsor URL on physical iOS + Android (RESEARCH device-verification item).

## Self-Check: PASSED

- lib/features/settings/presentation/widgets/legal_sponsor_section.dart — FOUND
- test/widget/features/settings/legal_sponsor_section_test.dart — FOUND
- lib/features/settings/presentation/widgets/about_section.dart — FOUND (slimmed)
- Commit fc67f32d (Task 1) — FOUND
- Commit e467033a (dev-deps) — FOUND
- Commit 8c327bf8 (Task 2) — FOUND
