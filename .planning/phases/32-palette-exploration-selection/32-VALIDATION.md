---
phase: 32
slug: palette-exploration-selection
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-01
---

# Phase 32 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
>
> **This is a design/artifact phase with NO automated test framework.** There is no production
> code to test (`lib/` is untouched). Validation is **artifact-existence + human-selection-checkpoint**
> based, not `flutter test` based. The phase gate (PALETTE-03) is a HARD human selection.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | **None** — no production code, no `flutter test` this phase. Validation = artifact checks + human checkpoint. |
| **Config file** | n/a |
| **Quick run command** | n/a — artifact inspection (`ls`, Pencil `get_variables` / `get_screenshot`, grep on synthesis + ADR docs) |
| **Full suite command** | n/a |
| **Estimated runtime** | n/a (visual + human review) |

---

## Sampling Rate

- **After every task commit:** Artifact inspection — confirm the task's output file/frame/variable exists and is complete (`ls`, `get_variables`, `get_screenshot`).
- **Per-scheme (during PALETTE-02):** `get_screenshot` visual check + WCAG contrast computation on load-bearing pairings; flag failures inline in the synthesis doc.
- **Pre-selection gate:** all 4–5 schemes complete (every semantic role answered, both light + dark) + accessibility flags documented → ready to present.
- **Phase gate (PALETTE-03):** HARD human-selection checkpoint — execution PAUSES; user picks one scheme or names a hybrid. ADR-018 status flips to ✅ 已接受 ONLY after this.
- **Max feedback latency:** n/a — visual/human, not timed test loops.

---

## Per-Task Verification Map

| Req ID | Behavior | Validation type | Concrete check | File Exists | Status |
|--------|----------|-----------------|----------------|-------------|--------|
| PALETTE-01 | ≥4 distinct directions synthesized with rationale + mined lineage | Artifact existence + content | Synthesis doc exists; contains ≥4 named directions; each names primary/Daily/Joy/surface stance + D-04/D-05 position + mined brand lineage | ❌ W0 | ⬜ pending |
| PALETTE-02 | Exactly 4–5 schemes × 3 screens × light+dark; each answers every semantic role | Artifact existence + completeness | `.pen` has 4–5 scheme groups; each = 6 frames (3 screens × 2 modes); `get_variables`/`get_screenshot` confirm every taxonomy role answered both modes; WCAG floor checked per scheme (flags recorded) | ❌ W0 | ⬜ pending |
| PALETTE-03 | User selects one/hybrid; recorded in accepted ADR-018 with hex per role | **Human checkpoint** + artifact | `checkpoint:human-verify` BEFORE ADR ratification; ADR-018 exists, status ✅ 已接受, complete hex-per-role table (light + dark) keyed by `AppColors` symbols; `ADR-000_INDEX.md` updated | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.pen` file does not exist yet — created fresh this phase. **First Pencil task MUST be `get_guidelines`** (validate conventions) → `open_document`, before any `batch_design`.
- [ ] No semantic `success/warning/error/info` family exists in the current palette — each scheme defines it net-new (feeds Phase 33).
- [ ] No contrast-verification artifact exists — executor computes WCAG ratios per scheme inline (no tooling install).

*No test-framework gaps — this phase has no automated tests by nature.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Palette selection (one scheme or named hybrid) | PALETTE-03 | Aesthetic + product judgment is inherently human; PALETTE-03 is a roadmap-locked hard gate before Phase 33 | Present all 4–5 schemes side-by-side (light + dark, 3 screens each via `get_screenshot`); user designates the winner or names a hybrid; record choice + final hex per role in ADR-018; flip status to 已接受 only after explicit user confirmation |
| Visual quality / "tasteful, no garish clash" (D-02) | PALETTE-01/02 | Subjective design quality not expressible as a contrast number | Reviewer eyeballs each scheme's home-hero / list / analytics frames in both modes |

*The entire phase gate is a human selection — there is no automated pass/fail.*

---

## Validation Sign-Off

- [ ] PALETTE-01 synthesis doc exists with ≥4 distinct directions, each with rationale + lineage + D-04/D-05 position
- [ ] PALETTE-02: exactly 4–5 `.pen` scheme groups, each 6 frames, every semantic role answered in light + dark, WCAG floors checked (failures flagged)
- [ ] PALETTE-03: human-selection checkpoint reached BEFORE ADR ratification (no premature 已接受)
- [ ] ADR-018 exists with complete hex-per-role table keyed to renamed `AppColors` symbols; `ADR-000_INDEX.md` updated
- [ ] No `lib/` changes (zero production code this phase)
- [ ] `nyquist_compliant: true` set in frontmatter (artifact-based — no automated suite expected)

**Approval:** pending
