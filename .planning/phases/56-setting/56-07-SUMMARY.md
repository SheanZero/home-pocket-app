---
phase: 56-setting
plan: 07
subsystem: legal-compliance
tags: [legal, tokusho, i18n-assets, gap-closure, uat, decision-reversal]
requires:
  - "assets/legal/tokusho_{ja,zh,en}.md (56-02)"
  - "LegalDocScreen verbatim asset rendering (56-04)"
  - "legal_asset_parity_test 8-header parity contract (56-01)"
provides:
  - "特商法 notice in full 表記型 (published operator fields) — LEGAL-04 / LEGAL-V2-01"
  - "D-06 decision superseding D-03 in 56-CONTEXT.md"
affects:
  - "UAT Test 4 (gap closed)"
tech_stack:
  added: []
  patterns:
    - "[上线前填真实值] placeholder convention (D-01/D-04) for pre-launch real values"
    - "append-only decision supersession (D-06 supersedes D-03)"
key_files:
  created:
    - .planning/phases/56-setting/deferred-items.md
  modified:
    - test/widget/features/settings/legal_doc_screen_test.dart
    - assets/legal/tokusho_ja.md
    - assets/legal/tokusho_zh.md
    - assets/legal/tokusho_en.md
    - .planning/phases/56-setting/56-CONTEXT.md
decisions:
  - "D-06 (supersedes D-03): publish operator fields directly (完整表記) instead of 請求時提供; real values held as [上线前填真实值] placeholders pending user + Japanese legal review"
metrics:
  duration: "~15m"
  completed: 2026-07-02
  tasks: 3
  files: 5
status: complete
---

# Phase 56 Plan 07: Reverse 特商法 Notice to Full 表記型 Summary

Reversed the 特定商取引法 notice from 請求時提供 (disclose-on-request, D-03) to full 表記型 — the tokusho page now publishes 事業者名 / 所在地 / 電話番号 / 運営責任者 directly across all three locales, with every real value (and the support email) held as a `[上线前填真实值]` placeholder pending the user's pre-launch fill-in and Japanese legal review. Closes UAT Test 4.

## What Changed

### Task 1 — Flip tokusho content-gate test (RED) · commit 3e64b614
- `legal_doc_screen_test.dart`: the tokusho content test now asserts `bodyText` contains `運営責任者` (a published-operator field present only after the full-表記 rewrite) instead of `請求`.
- Test renamed to reference "published operator fields (full 表記型 — LEGAL-04 / D-06 supersedes D-03)"; inline comment rewritten. No other test touched (AppBar `tokushoNotice` test left as-is — ARB label out of scope).
- RED verified statically (assertion/name flipped; test not run as this task's gate).

### Task 2 — Rewrite trilingual tokusho assets to full 表記型 (GREEN) · commit b672d46b
- `tokusho_{ja,zh,en}.md`: `販売事業者・運営者` / `連絡先` / `前提` section bodies rewritten; the other 5 sections (販売価格, 対価以外の必要料金, 支払方法・支払時期, 役務の提供時期, 返品・キャンセル) left byte-unchanged.
- Operator fields published as a labeled list, each value = `[上线前填真实值]`; support email → `support@example.com [上线前填真实值]`.
- Removed: 請求時提供 disclosure sentences, `住所・電話番号を公開しておりません` / `不公开地址与电话号码` / "not published on this page", the v2-deferral preamble clause, and the `請求時提供型` footer clause (all 3 locales).
- Preserved: the pre-launch Japanese-legal-review marker in each file (top blockquote softened to reflect full 表記 pending legal PII confirmation, but the legal-review sentence retained).
- Exactly 8 `## ` section headers per locale retained → parity gate GREEN.

### Task 3 — Record D-06, pull LEGAL-V2-01 forward (append-only) · commit 9a310048
- `56-CONTEXT.md`: added `### 特商法（LEGAL-04）运营者信息呈现 —— 反转（supersedes D-03）` with the D-06 bullet (after D-05, before Claude's Discretion), including the explicit privacy trade-off note.
- Appended ` **[SUPERSEDED by D-06 — 2026-07-02, see below]**` to the D-03 bullet — D-03 rationale body left byte-unchanged.
- Marked LEGAL-V2-01 in Deferred Ideas as `**[已前移 2026-07-02]**` (no longer deferred); the "真实运营者联系方式" pre-launch-fill-in deferred bullet left unchanged.

## Verification

- `flutter analyze` — **No issues found!** (0 issues).
- `flutter test test/architecture/legal_asset_parity_test.dart test/widget/features/settings/legal_doc_screen_test.dart` — **All tests passed** (12/12); parity gate + flipped tokusho assertion GREEN.
- grep gates: each tokusho contains `[上线前填真实值]`; `tokusho_ja.md` contains `運営責任者`; `公開しておりません` / `不公开地址与电话号码` / "not published on this page" / `請求時提供型` all removed; header counts ja/zh/en = 8/8/8.
- Full suite (`flutter test`, exit code preserved, not piped through tail): **3492 passed / 1 failed**. See Deferred Issues.

## Deferred Issues

**1 pre-existing full-suite failure — OUT OF SCOPE for 56-07 (logged in `deferred-items.md` as DEF-56-07-01):**
- `test/architecture/production_logging_privacy_test.dart` flags `lib/features/settings/presentation/widgets/legal_sponsor_section.dart:50` — an unguarded `debugPrint('sponsor launch failed: $e')`.
- Root: added by commit `1ef10af6` (2026-07-01, plan **56-06** "IN-03"), BEFORE 56-07 started. `git diff --name-only` confirms none of 56-07's three commits touched `legal_sponsor_section.dart`.
- Not fixed here: `legal_sponsor_section.dart` is outside 56-07's files_modified list (owned by 56-06); the scope boundary forbids editing it. Suggested fix: wrap the `debugPrint` in `if (kDebugMode)`.
- **This is not a regression from 56-07.** The plan's own scoped success criteria (parity gate, flipped widget test, analyze 0) are all met.

## Deviations from Plan

None to the plan's task actions. The full-suite post-gate surfaced one pre-existing, out-of-scope failure (documented above and in deferred-items.md) rather than a regression from this plan's changes.

## Self-Check: PASSED
- assets/legal/tokusho_{ja,zh,en}.md — present, rewritten, 8 headers each.
- test/widget/features/settings/legal_doc_screen_test.dart — flipped, GREEN.
- .planning/phases/56-setting/56-CONTEXT.md — D-06 recorded, D-03 pointer added, LEGAL-V2-01 pulled forward.
- Commits 3e64b614, b672d46b, 9a310048 exist in git log.
