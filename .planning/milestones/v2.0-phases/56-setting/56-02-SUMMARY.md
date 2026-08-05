---
phase: 56-setting
plan: 02
subsystem: legal-compliance
tags: [legal, privacy, terms, tokusho, i18n, launch-compliance, assets]
requires:
  - 56-CONTEXT.md D-01/D-02/D-03 (trilingual launch drafts, bundled per-locale assets, 請求時提供 型)
provides:
  - assets/legal/privacy_{ja,zh,en}.md (LEGAL-01 trilingual privacy policy draft)
  - assets/legal/terms_{ja,zh,en}.md (LEGAL-02 trilingual terms of use draft)
  - assets/legal/tokusho_{ja,zh,en}.md (LEGAL-04 trilingual 特商法 notice, 請求時提供 型)
affects:
  - 56-01 legal_asset_parity_test (turns GREEN once these 9 files exist)
  - 56-04 LegalDocScreen (renders these verbatim as plain text)
  - 56-06 store-privacy checklist (must share the same data-flow 口径)
tech-stack:
  added: []
  patterns:
    - bundled per-locale markdown assets under assets/legal/ (D-02) — long legal text kept out of ARB
key-files:
  created:
    - assets/legal/privacy_ja.md
    - assets/legal/privacy_zh.md
    - assets/legal/privacy_en.md
    - assets/legal/terms_ja.md
    - assets/legal/terms_zh.md
    - assets/legal/terms_en.md
    - assets/legal/tokusho_ja.md
    - assets/legal/tokusho_zh.md
    - assets/legal/tokusho_en.md
  modified: []
decisions:
  - "Privacy 口径 is non-reflexive: explicitly discloses the v1.7 exchange-rate outbound fetch AND the FCM push-token registration (firebase_messaging ^16.0.1 is in pubspec) — never a blanket 完全不収集 (D-01)"
  - "特商法 uses 請求時提供 型: operator name/address/phone disclosed on request + placeholder support@example.com only; no home address/phone published (D-03)"
  - "All long legal text authored as bundled per-locale markdown assets under assets/legal/, not ARB (D-02)"
metrics:
  duration_minutes: 8
  completed: 2026-07-01
  tasks_completed: 3
  files_created: 9
status: complete
---

# Phase 56 Plan 02: Trilingual Legal Launch Drafts Summary

Authored complete, truthful trilingual (ja/zh/en) launch DRAFTS for the three legal documents — privacy policy (LEGAL-01), terms of use (LEGAL-02), and 特定商取引法に基づく表記 (LEGAL-04) — as nine bundled per-locale markdown assets under `assets/legal/`, grounded in the app's real local-first / zero-knowledge behavior, with a 請求時提供 型 特商法 notice and a visible pre-launch legal-review marker in every file.

## What Was Built

| Task | Document | Files | Commit |
|------|----------|-------|--------|
| 1 | Privacy policy (LEGAL-01) | `privacy_{ja,zh,en}.md` | `0cb836cd` |
| 2 | Terms of use (LEGAL-02) | `terms_{ja,zh,en}.md` | `c125ce71` |
| 3 | 特商法 notice, 請求時提供 型 (LEGAL-04) | `tokusho_{ja,zh,en}.md` | `28a79b0a` |

### Task 1 — Privacy policy
Trilingual privacy policy as parallel translations. Content grounded in real behavior: (1) on-device storage protected by the 4-layer encryption stack, zero-knowledge (developer cannot read financial data); (2) truthful enumeration of the ONLY outbound flows — the v1.7 exchange-rate fetch (為替/汇率/exchange rate; no personal/financial data sent) and, when push notifications are enabled, FCM push-token registration with Google; (3) family sync is device-to-device E2EE with no server storage; (4) no ads, no analytics/tracking SDK; (5) placeholder contact email + hosted-URL note. The 口径 is deliberately non-reflexive — it names the real network calls rather than claiming 完全不収集.

### Task 2 — Terms of use
Trilingual 利用規約 covering scope/acceptance, license, free-of-charge with no in-app purchase, voluntary external donation (no obligation, no feature gating — consistent with DONATE-03), user responsibilities and prohibited uses, disclaimer of warranty, limitation of liability, changes to terms, governing law (Japan) + jurisdiction, and a placeholder contact.

### Task 3 — 特商法 notice (請求時提供 型)
Trilingual 特定商取引法に基づく表記 using the napu.co.jp/sale item organization for headings but with 請求時提供 content per D-03: operator info (name/address/phone) disclosed without delay on request; only a placeholder `support@example.com` published; NO home address or phone number. Notes the app is free with only voluntary external donation (no product sale / 対価), and adds the caveat that 特商法 applicability and full-表記 necessity will be confirmed 上线前 by Japanese legal counsel (full 表記 deferred to v2 LEGAL-V2-01).

## Verification

- All 9 `assets/legal/*.md` exist and are non-empty — confirmed.
- Privacy drafts name the real fx outbound flow: `為替` (ja), `汇率` (zh), `exchange` (en) — confirmed.
- 特商法 ja contains `請求` (請求時提供 型) — confirmed.
- No home address / phone published: grepped all `tokusho_*.md` for phone patterns (`NN-NNNN-NNNN`, `〒`, `+81`) — none found; only placeholder email present.
- All 9 files carry a pre-launch legal-review marker — confirmed (9/9).
- `test/architecture/legal_asset_parity_test.dart` does not yet exist — it is authored by 56-01, which runs after this plan in wave 1; these 9 files satisfy that gate once present. Not run here by design.
- CJK content lives in `assets/`, outside `lib/`, so the `hardcoded_cjk_ui_scan` gate is unaffected.

## Deviations from Plan

None — plan executed exactly as written. All acceptance criteria met via automated greps in each task's verify block.

## Notes for Downstream

- **56-04 (LegalDocScreen):** renders these verbatim as plain text (SelectableText). Content is authored as readable prose/headings; no rich-markdown rendering is required.
- **56-06 (store-privacy checklist / LEGAL-05):** must share this data-flow 口径 — the two real outbound flows are (1) v1.7 exchange-rate fetch and (2) FCM push-token registration when push notifications are enabled. These are the single source of truth for what leaves the device.
- **Placeholders to fill 上线前 (user, out of this phase's scope):** `support@example.com` across all 9 files; hosted public URL for privacy/terms; real operator contact for 特商法 請求時提供 disclosure.
- **All 9 files are DRAFTS** carrying a visible pre-launch legal-review marker; final accuracy is gated by Japanese legal review (D-01).

## Self-Check: PASSED

- assets/legal/privacy_{ja,zh,en}.md — FOUND
- assets/legal/terms_{ja,zh,en}.md — FOUND
- assets/legal/tokusho_{ja,zh,en}.md — FOUND
- Commit 0cb836cd — FOUND
- Commit c125ce71 — FOUND
- Commit 28a79b0a — FOUND
