# Phase 61: Android Toolchain & Emulator Lane - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-09
**Phase:** 61-android-toolchain-emulator-lane
**Mode:** `--auto`
**Areas discussed:** Atomic candidate or hold, Built-in Kotlin and DSL boundary, Release signing and artifact hygiene, Emulator and evidence boundary

---

## Atomic Candidate or Hold

| Option | Description | Selected |
|--------|-------------|----------|
| Atomic production-stable lane | Re-query official sources, evaluate AGP/Gradle/JDK/API as one graph, and adopt only with complete app/plugin evidence | ✓ |
| Dated candidate without re-query | Treat the 2026-08-05 versions as immutable | |
| Independent upgrades | Move individual host components when each appears compatible | |

**Auto-selected choice:** Atomic production-stable lane. Any blocker restores the named last-green AGP 8 graph and records an exit condition.

---

## Built-in Kotlin and DSL Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| One indivisible migration | Built-in Kotlin, new DSL, KGP removal, and opt-out cleanup land together across app and plugins | ✓ |
| Staged cleanup | Retain some legacy flags or KGP while other AGP 9 pieces land | |
| App-only modernization | Ignore incompatible plugin subprojects | |

**Auto-selected choice:** One indivisible migration, proven first in a disposable workspace. Existing Phase 59 dependency holds are not silently reopened.

---

## Release Signing and Artifact Hygiene

| Option | Description | Selected |
|--------|-------------|----------|
| Ephemeral non-debug evidence key | Build and inspect release AAB plus APK without production credentials | ✓ |
| Production upload key | Use real store credential material during the phase | |
| Unsigned/debug/config-only | Substitute a weaker artifact for release acceptance | |

**Auto-selected choice:** Ephemeral non-debug evidence key outside the repository, both AAB and APK, negative missing/debug credential cases, hashes/signature metadata, and packaged-artifact test-plugin scans.

---

## Emulator and Evidence Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Fresh API 36 Emulator | Run the complete integration suite and retain named critical-journey/provenance evidence | ✓ |
| Existing API 35 smoke | Keep the old CI floor and run only a narrow smoke | |
| Physical-device dependency | Wait for Android hardware before accepting the phase | |

**Auto-selected choice:** Fresh supported API 36 x86_64 Emulator, complete `integration_test/` execution, redacted toolchain/artifact provenance, and an explicit statement that Android physical-device validation was not performed or claimed.

## the agent's Discretion

- Runner/evidence file names, isolated-candidate mechanism, AVD name, diagnostic partitioning, artifact inspection utilities, and evidence layout.
- Additional fail-closed mutation tests that preserve the locked phase boundary.

## Deferred Ideas

- Phase 59 plugin upgrades, Phase 62 cross-platform convergence, Phase 63 wired-iPhone acceptance, and unavailable Android physical-device testing.
