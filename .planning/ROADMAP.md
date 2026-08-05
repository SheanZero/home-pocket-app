# Roadmap: Home Pocket

## Milestones

- ✅ **v1.0 Codebase Cleanup Initiative** — Phases 1-8 (shipped 2026-04-29) — [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Happiness Metric & Display** — Phases 9-12 (shipped 2026-05-05) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Happiness Metric Refresh** — Phases 13-17 (shipped 2026-05-21) — [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 迭代帐本输入** — Phases 18-23 (shipped 2026-05-26) — [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 列表功能** — Phases 24-30 (shipped 2026-05-31) — [archive](milestones/v1.4-ROADMAP.md)
- ✅ **v1.5 文案与配色统一** — Phases 31-35 (shipped 2026-06-02) — [archive](milestones/v1.5-ROADMAP.md)
- ✅ **v1.6 购物清单** — Phases 36-39 (shipped 2026-06-12) — [archive](milestones/v1.6-ROADMAP.md)
- ✅ **v1.7 多币种支持** — Phases 40-42 (shipped 2026-06-14) — [archive](milestones/v1.7-ROADMAP.md)
- ✅ **v1.8 统计页面重设计（实用化 × 悦己情感化）** — Phases 43-48 (shipped 2026-06-22) — [archive](milestones/v1.8-ROADMAP.md)
- ✅ **v1.9 语音类目与商家识别系统重构** — Phases 49-52 (shipped 2026-06-25) — [archive](milestones/v1.9-ROADMAP.md)
- ✅ **v2.0 完成第一版上线前最后的功能开发** — Phases 53-56 (shipped and archived 2026-08-05) — [roadmap](milestones/v2.0-ROADMAP.md) · [requirements](milestones/v2.0-REQUIREMENTS.md) · [audit](milestones/v2.0-MILESTONE-AUDIT.md)

<details>
<summary>✅ v2.0 archived phase index (Phases 53-56)</summary>

- [x] **Phase 53: HTML Design Gate** — 4/4 plans complete; three design directions approved; zero-production-code gate passed.
- [x] **Phase 54: Onboarding Flow** — 7/7 plans complete; canonical close verification reconciled to the live V16 intro → settings flow with inline optional security.
- [x] **Phase 55: App Lock (Face ID + PIN)** — 12/12 plans complete; 6/6 device UAT complete; G1-G4 fixed and verified.
- [x] **Phase 56: Legal, Sponsor, and Release Settings** — 7/7 plans complete; offline trilingual legal surfaces and release documentation verified.

Full plan and verification history: `.planning/milestones/v2.0-phases/`.

</details>

## Current Planning State

No milestone or phase is active. v2.0 closed with audit status `tech_debt`: 32/32 requirements covered, 4/4 phases passed, 12/12 integration seams wired, and 6/6 E2E flows complete. The user explicitly accepted the documented historical artifact and release-configuration debt at close; see `.planning/STATE.md` Deferred Items §v2.0.

Before creating the next roadmap:

1. ✅ `.planning/codebase/` refreshed 2026-08-05 against the post-P1/P2 working tree (map base `7b4f1bac`).
2. Resolve or explicitly schedule the release-owner values listed in STATE: hosted Privacy/Terms URLs, app-specific support/sponsor destinations, Tokusho operator identity/contact information, and legal review.
3. Run `$gsd-new-milestone`; that workflow will create the next active `REQUIREMENTS.md` and phase roadmap.

## Backlog

- App-lock progressive PIN retry delay (`LOCK-V2-04`) remains deliberately descoped from v2.0.
- Preserve historical deferred items in `.planning/STATE.md`; promote only work that belongs to the next milestone goal.
