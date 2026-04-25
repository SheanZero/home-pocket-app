---
status: issues_found
phase: 01
depth: quick
files_reviewed: 16
findings_critical: 0
findings_high: 2
findings_medium: 6
findings_low: 5
---

# Phase 1: Code Review Report

**Reviewed:** 2026-04-25
**Depth:** quick
**Files Reviewed:** 16
**Status:** issues_found

## Summary

Phase 1 produced infrastructure-only code: 4 Dart audit scanners, 4 thin shell wrappers, the merger, a stub for `reaudit_diff`, two shell test harnesses, a Dart unit test, an installer, and the GitHub Actions workflow. The discovery-only constraint is respected — no script writes into `lib/`, only into `.planning/audit/`. No hardcoded secrets, no `eval`, no command injection vectors via user-controllable input (every `Process.run` argument list is a fixed string literal).

The findings below cluster around three themes: (1) Pitfall P1-9 / P1-10 contract drift between research and implementation (severity is hardcoded blanket-per-tool rather than per-rule; malformed shards are skipped rather than failing fast), (2) Windows portability gaps in `_relPath` and the generated-file detector, and (3) GitHub Actions supply-chain hygiene (action pins use floating major tags, no `permissions:` declared). All are non-blocking for the intended Linux/macOS local + Linux CI runtime.

## High

### HR-01: Severity drift — scanners blanket-assign severity per scanner, not per rule (Pitfall P1-9 contract)

**File:** `scripts/audit/layer.dart:42`, `scripts/audit/providers.dart:42`, `scripts/audit/dead_code.dart:101,120`
**Issue:** Pitfall P1-9 in `01-RESEARCH.md` requires severity be locked via a static map keyed by `(tool_source, code)` — different `import_guard:*` and `riverpod:*` codes warrant different severities. Current implementation hardcodes every layer finding as `CRITICAL`, every provider finding as `HIGH`, and every dead-code finding as `LOW` regardless of which lint code fired. A `riverpod_lint` rule for a `keepAlive` regression and one for a deprecated `Ref.read` end up with the same `HIGH` severity, which collapses the Phase 4/5/6 fix-priority ordering. The merger relies on this severity to drive phase-mapping (D-04), so blanket assignment loses signal.
**Fix:** Add a static `Map<String, String>` keyed by `<code>` in each scanner (or, per P1-9, in the merger) and look up severity per finding. Example for `layer.dart`:
```dart
const _severityByCode = <String, String>{
  'import_guard_domain_imports_data': 'CRITICAL',
  'import_guard_features_use_cases': 'CRITICAL',
  'import_guard_presentation_imports_infra': 'HIGH',
};
final severity = _severityByCode[code] ?? 'CRITICAL';
```

### HR-02: Malformed-shard handling skips silently instead of failing fast (Pitfall P1-10 contract)

**File:** `scripts/merge_findings.dart:46-50`
**Issue:** Pitfall P1-10 explicitly requires "a JSON-schema validator step in `merge_findings.dart` that fails fast on missing fields." Current code logs a stderr warning and continues, which means a malformed AI-agent shard silently drops findings and CI still produces a green `issues.json`. Combined with `continue-on-error: true` on the audit step in `audit.yml:44`, an entire shard could be lost without any blocking signal. Re-audit reconciliation in Phase 8 (`reaudit_diff.dart`) will then incorrectly classify the dropped findings as "regressions" or "fixes."
**Fix:** Track a `malformedCount` counter and exit non-zero if any finding fails to parse, OR write a `manifest.json` next to `issues.json` that records `parsed_count` / `dropped_count` per shard so downstream tooling can detect drops. Minimum viable change: `exit(2)` after the loop if `malformedCount > 0`.

## Medium

### MR-01: `_relPath` and generated-file detector are not Windows-safe

**File:** `scripts/audit/layer.dart:14-20`, `scripts/audit/providers.dart:14-20`, `scripts/audit/dead_code.dart:14-20`, `scripts/merge_findings.dart:19-20`
**Issue:** `_relPath` checks `absPath.startsWith('$cwd/')` with a hardcoded forward slash, and `_isGenerated` uses `path.contains('lib/generated/')`. On Windows, `Directory.current.path` returns `C:\...\home-pocket-app` and analyzer-reported file URIs use backslashes; the relative-path stripping fails (paths stay absolute, breaking the SCHEMA.md "NEVER absolute" mitigation T-1-03-02) and the `lib/generated/` filter passes everything through.
**Fix:** Use `package:path` (or `Platform.pathSeparator`) for path joins, and normalize separators before pattern matching:
```dart
final normalized = path.replaceAll(r'\', '/');
return _generatedFileSuffixes.any(normalized.endsWith) ||
       normalized.contains('/lib/generated/');
```

### MR-02: `--reporter=json` flag may not exist on `custom_lint` 0.7.x

**File:** `scripts/audit/layer.dart:69-74`, `scripts/audit/providers.dart:68-73`
**Issue:** Pitfall P1-8 in research uses `--format=json`, but the implementation uses `--reporter=json`. The `custom_lint` CLI in 0.7.x accepts `--format=<reporter>` (where reporter values include `json`), not `--reporter=json` directly. If the flag is unrecognized, `dart run` will error and the JSON path always returns empty, forcing the slower text-reporter fallback every run. The fallback works (`--no-fatal-infos` alone runs the default reporter), but the JSON branch is dead code and re-runs cost ~2x the time.
**Fix:** Verify the flag against `dart run custom_lint --help` and either change to `--format=json` or remove the dead JSON branch entirely. If `custom_lint` does not yet support JSON output in 0.7.6, drop the JSON path and rely on the regex parser.

### MR-03: Text-reporter regex assumes a Unicode bullet (`•`) literal

**File:** `scripts/audit/layer.dart:23-25`, `scripts/audit/providers.dart:23-25`
**Issue:** The regex `^\s*([^:]+\.dart):(\d+):(\d+)\s+•\s+(.+?)\s+•\s+(\S+)\s+•\s+(INFO|WARNING|ERROR)\s*$` hardcodes the bullet character `•`. If `custom_lint` updates its reporter to use ASCII separators or a different Unicode glyph (newer analyzer versions have changed this), the parser silently captures zero findings — same failure mode as P1-1 (green CI on a non-functional gate). No version pin guards against the format change.
**Fix:** Loosen the regex to accept any non-alphanumeric separator: `\s*[^\w\s]\s+`, OR add a smoke test that runs `custom_lint` against a known-violation fixture and asserts ≥1 finding parsed. The `test_audit_pipeline.sh` schema check only asserts shape, not non-empty.

### MR-04: `audit.yml` GitHub Actions are pinned to floating major tags, not commit SHAs

**File:** `.github/workflows/audit.yml:17,18,22,52,65,66,100`
**Issue:** Five third-party actions pinned by major tag (`actions/checkout@v4`, `subosito/flutter-action@v2`, `actions/cache@v4`, `actions/upload-artifact@v4`, `VeryGoodOpenSource/very_good_coverage@v2`). A compromised maintainer or tag-rewrite (Tj-actions/changed-files Mar-2025 incident) silently injects malicious code into every PR run. GitHub's own hardening guide recommends commit-SHA pinning for security-sensitive workflows.
**Fix:** Replace tag refs with full 40-char commit SHAs and add a comment with the human-readable version:
```yaml
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
```
Use `dependabot.yml` `ignore` + `update` rules to keep them current. Alternative for moderate-trust adoption: keep tags but add `pull_request_target` review and require workflow-edit reviews on protected branches.

### MR-05: `audit.yml` does not declare `permissions:` — workflows run with default token scope

**File:** `.github/workflows/audit.yml:1-13`
**Issue:** No top-level or job-level `permissions:` block. The workflow inherits the repo's default `GITHUB_TOKEN` permissions, which on legacy repos can be `read-write` for all scopes. The `upload-artifact` step needs `contents: read` only; `guardrails` needs nothing more than checkout. A compromised dependency in any job (see MR-04) could push to `main` if the token is broad.
**Fix:** Add at the top of `audit.yml`:
```yaml
permissions:
  contents: read
```
And only widen on jobs that need it (none here do beyond read).

### MR-06: `test_idempotency.sh` uses fixed `/tmp/audit_run1.json` — race + stale-file risk

**File:** `scripts/test_idempotency.sh:7,11,13`
**Issue:** Two developers (or two CI matrix jobs on the same self-hosted runner) running the test concurrently overwrite each other's snapshot. A leftover `/tmp/audit_run1.json` from a prior failed run also masks new diffs.
**Fix:** Use `mktemp`:
```bash
SNAPSHOT=$(mktemp /tmp/audit_run1.XXXXXX.json)
trap 'rm -f "$SNAPSHOT"' EXIT
cp .planning/audit/issues.json "$SNAPSHOT"
...
diff -q "$SNAPSHOT" .planning/audit/issues.json
```

## Info

### IR-01: `reaudit_diff.dart` stub silently ignores arguments

**File:** `scripts/reaudit_diff.dart:5`
**Issue:** `void main()` (no args parameter) — if a caller passes arguments expecting Phase 8 behavior, they are dropped without warning. Acceptable for a stub but worth a deprecation/TODO marker.
**Fix:** Either accept `List<String> args` and log a notice, or rename to `reaudit_diff_stub.dart` so the file lookup intent is unambiguous.

### IR-02: `install_audit_tools.sh` doesn't verify activated coverde version

**File:** `scripts/install_audit_tools.sh:9-15`
**Issue:** After `dart pub global activate coverde 0.3.0+1`, no `coverde --version` check confirms the tool actually activated at the pinned version. If pub.dev yanks 0.3.0+1, `activate` fails with non-zero exit (caught by `set -e`) — OK. But if a stale globally-activated coverde exists on the runner from a prior build, `activate` may no-op silently.
**Fix:** Add a verification step after activation:
```bash
ACTIVATED_VERSION=$(coverde --version 2>&1 | head -1)
echo "[audit:install] coverde activated: $ACTIVATED_VERSION"
```

### IR-03: `audit.yml` build_runner job uses deprecated invocation form

**File:** `.github/workflows/audit.yml:82`
**Issue:** `flutter pub run build_runner build --delete-conflicting-outputs` — the `flutter pub run` form is soft-deprecated in favor of `dart run build_runner build` since Flutter 3.x. Still works but emits a deprecation warning.
**Fix:** Change to `dart run build_runner build --delete-conflicting-outputs`.

### IR-04: `merge_findings.dart` hardcodes paths — not configurable for tests

**File:** `scripts/merge_findings.dart:24,106,117`
**Issue:** Output paths are hardcoded to `.planning/audit/...`. The unit test in `test/scripts/merge_findings_test.dart` works around this by `chdir`-ing into a temp directory and copying the script. A `--root <dir>` flag would simplify both testing and a future "compare two audit baselines" workflow.
**Fix:** Accept an optional `args[0]` as project root and resolve all paths against it. Non-blocking — current test approach proves the contract works.

### IR-05: `test_audit_pipeline.sh` requires Python 3 — implicit dependency

**File:** `scripts/test_audit_pipeline.sh:21-39`
**Issue:** Inline `python3 - <<EOF` for schema validation. Most macOS / Linux dev machines and `ubuntu-latest` runners ship Python 3, but the requirement isn't documented in CLAUDE.md or the phase summary. A developer on a Python-less environment (bare Alpine, minimal nix shell) will see an unhelpful "python3: command not found" error.
**Fix:** Either document Python 3 as a dev requirement in `CLAUDE.md`'s "Essential Commands" section, OR rewrite the validator in pure shell + `jq`, OR add a Dart-side validator script that uses the existing Dart toolchain.

---

_Reviewed: 2026-04-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: quick_
