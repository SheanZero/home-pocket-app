# Sketch Manifest

## Design Direction
Pre-launch gates for Home Pocket (まもる家計簿): first-run onboarding, app-lock, and the
Settings legal/sponsor block. Grounded in ADR-019 桜餅×若葉 (Sakura Mochi × Wakaba): warm
cream background, leaf-green primary, sakura-pink accent reserved for joy/CTA warmth, large
radii, soft shadows. Trilingual (ja default / zh / en). Each surface is sketched in three
tones per the user's request: **A 温柔抛茶感** (warm, family-app), **B 清爽极简** (system-native,
cool/professional), **C 混合** (warm welcome + calm trust on sensitive screens). Throwaway HTML
only — zero production Dart.

## Reference Points
- ADR-019 palette (`lib/core/theme/app_palette.dart`)
- Current Home assembly (`HomeScreen`, `HomeHeroCard`, `HeroHeader`, `TransactionListCard`, `HomeBottomNavBar`)
- ADR-016 single Joy expression (`Σ joy_contribution`) and no-celebration-at-100% constraint
- iOS system onboarding / Face ID lock conventions
- Japanese store-compliance: 特定商取引法, 利用規約, プライバシーポリシー, OSS ライセンス

## Current Whole-App Reference — 2026-07-15

The selected warm-Japanese whole-app design has graduated from planning sketches into the canonical
interactive reference at [`docs/mockup/v16/index.html`](../../docs/mockup/v16/index.html). V16 is
synchronized with the current Flutter main-surface headers and shopping filters. Do not keep a
second whole-app HTML copy under `.planning/sketches`.

This directory retains only the still-relevant pre-launch input sketches 001–003. Historical audits,
quick experiments, and milestone archives remain in their own evidence directories and are not
current whole-app mockups.

## Sketches

| # | Name | Design Question | Winner | Tags |
|---|------|----------------|--------|------|
| 001 | onboarding-gate | First-run intro page → default-only basic settings with on-demand picker modal | **A · 温柔抛茶感** | onboarding, gate, i18n |
| 002 | app-lock | Separate Face ID page + PIN page, chosen by settings; Face ID preferred when both on | **B · 清爽极简** (light + dark) | security, lock, biometric |
| 003 | legal-sponsor | Complete Settings page = existing 8 sections + App Lock expansion + legal + external sponsor | **C · 混合** | settings, legal, compliance, app-lock |

## Decisions
- **001 = A (温柔抛茶感):** two-step first run — intro page (value prop) → basic settings showing
  defaults only, each row a 変更 picker modal, "change later in Settings" hint. Single intro page.
- **002 = B (清爽极简), with light mode:** system-native lock, follows app theme. Two separate
  surfaces (Face ID page / PIN page); Face ID preferred when both enabled, PIN is fallback.
  Mockup now shows both a light-mode set and a dark-mode set.
- **003 = C (混合):** complete Settings page. Merged 一般 group (appearance + voice + joy target),
  App Lock expanded under セキュリティ (master + Face ID + PIN + priority note), and a single
  法的情報・応援 group (Privacy / Terms / 特商法 / OSS + external 応援 row).
