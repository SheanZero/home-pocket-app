# Coverage gate scope

`coverage-gate-required-files.txt` is the blocking per-file coverage manifest
used by CI. It is a deliberate risk manifest, not a history-derived list of
everything modified during the v1.0 cleanup initiative.

The retired `cleanup-touched-files.txt` contains 170 Phase 3–6 frontmatter
entries. Against the current clean LCOV it contained 109 absent paths: generated
Riverpod/Drift/Freezed output, generated localizations, ARB source, YAML import
guards, and cleanup-era executable files that had dropped out of the current
test run. The old gate warned and continued on each absence, so that input could
not prove coverage of the claimed surface.

The new manifest contains only tracked, hand-written Dart files that contain
executable security or data-integrity behavior:

- encrypted backup export, import, restore, and crypto;
- relay, WebSocket, push, queue, scheduler, and lifecycle transport code; and
- family-sync pull/push/full-sync, engine, and orchestration write barriers.

Generated `*.g.dart`, `*.freezed.dart`, and `*.mocks.dart`, `lib/generated/**`,
ARB files, YAML import guards, and enum/data-only declarations are explicitly
out of scope because `coverde filter` removes them or they have no executable
lines. They must not be reintroduced through a broad historical manifest.

`coverage-gate-deferred.txt` records zero active exclusions. The previous 11
entries belonged to the retired cleanup manifest; nine named removed files and
the remaining two were unrelated provider wiring. New exceptions must name a
tracked hand-written Dart file and supply a file-specific rationale; no wildcard
or category-level deferral is allowed. Any required file absent from LCOV fails
the gate.
